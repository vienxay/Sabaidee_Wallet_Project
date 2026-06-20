/**
 * Reset all data in db_SabaideeWallet
 * - Keep admin/staff accounts (role: admin, staff)
 * - Delete all regular users, transactions, wallets, KYC, expenses, notifications, profiles
 * - Reset admin wallets to 0 balance
 * - Clear admin OTP/KYC fields
 *
 * Usage:
 *   node src/scripts/reset_all_data.js --dry-run     (preview only)
 *   node src/scripts/reset_all_data.js --confirm      (actually reset)
 */
require('dotenv').config()
const { execSync } = require('child_process')
const path = require('path')
const fs = require('fs')
const mongoose = require('mongoose')

const args = process.argv.slice(2)
const isDryRun = args.includes('--dry-run')
const isConfirm = args.includes('--confirm')

if (!isDryRun && !isConfirm) {
  console.log('Usage:')
  console.log('  node src/scripts/reset_all_data.js --dry-run   (preview what will be deleted)')
  console.log('  node src/scripts/reset_all_data.js --confirm   (actually delete data)')
  process.exit(0)
}

async function backup() {
  const backupDir = path.join(__dirname, '..', '..', 'backups')
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const backupPath = path.join(backupDir, `backup_${timestamp}`)

  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true })

  try {
    execSync(`mongodump --uri="${process.env.MONGO_URI}" --out="${backupPath}"`, { stdio: 'inherit' })
    console.log(`\nBackup saved to: ${backupPath}\n`)
    return true
  } catch {
    console.error('\nmongodump failed — install MongoDB Database Tools or skip backup.')
    console.error('Download: https://www.mongodb.com/try/download/database-tools\n')
    return false
  }
}

async function countCollection(db, name) {
  const collections = (await db.listCollections().toArray()).map(c => c.name)
  if (!collections.includes(name)) return 0
  return db.collection(name).countDocuments()
}

async function resetAll() {
  if (!process.env.MONGO_URI) {
    console.error('MONGO_URI not found in .env')
    process.exit(1)
  }

  // Environment safety check
  if (process.env.NODE_ENV === 'production') {
    console.error('BLOCKED: cannot run reset in production environment')
    process.exit(1)
  }

  await mongoose.connect(process.env.MONGO_URI)
  console.log('Connected to MongoDB')
  console.log(`Database: ${mongoose.connection.db.databaseName}`)
  console.log(`Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'LIVE RESET'}\n`)

  const db = mongoose.connection.db

  const collections = (await db.listCollections().toArray()).map(c => c.name)
  console.log('Collections found:', collections.join(', '))

  // Find admin/staff accounts
  const adminUsers = await db.collection('users').find(
    { role: { $in: ['admin', 'staff'] } },
    { projection: { _id: 1, name: 1, role: 1, wallet: 1 } }
  ).toArray()

  const adminIds = adminUsers.map(u => u._id)
  const adminWalletIds = adminUsers.map(u => u.wallet).filter(Boolean)

  // Count what will be affected
  const counts = {
    transactions:  await countCollection(db, 'transactions'),
    kycs:          await countCollection(db, 'kycs'),
    expenses:      await countCollection(db, 'expenses'),
    notifications: await countCollection(db, 'notifications'),
    profiles:      await countCollection(db, 'profiles'),
    regularUsers:  collections.includes('users')
      ? await db.collection('users').countDocuments({ role: { $nin: ['admin', 'staff'] } })
      : 0,
    nonAdminWallets: collections.includes('wallets')
      ? await db.collection('wallets').countDocuments({ user: { $nin: adminIds } })
      : 0,
    adminWallets:  adminWalletIds.length,
  }

  console.log('\n--- Will be DELETED ---')
  console.log(`  Transactions:       ${counts.transactions}`)
  console.log(`  KYC records:        ${counts.kycs}`)
  console.log(`  Expenses:           ${counts.expenses}`)
  console.log(`  Notifications:      ${counts.notifications}`)
  console.log(`  Profiles:           ${counts.profiles}`)
  console.log(`  Regular users:      ${counts.regularUsers}`)
  console.log(`  Non-admin wallets:  ${counts.nonAdminWallets}`)

  console.log('\n--- Will be RESET ---')
  console.log(`  Admin wallets → 0:  ${counts.adminWallets}`)
  console.log(`  Admin KYC → none:   ${adminUsers.length}`)
  console.log(`  Admin OTP → clear:  ${adminUsers.length}`)

  console.log('\n--- Will be KEPT ---')
  adminUsers.forEach(u => console.log(`  ${u.name} (${u.role})`))
  console.log(`  Rates config:       kept (not user data)`)

  if (isDryRun) {
    console.log('\n=== DRY-RUN complete — no changes made ===')
    console.log('Run with --confirm to execute the reset.')
    await mongoose.disconnect()
    return
  }

  // Backup before destructive operation
  console.log('\n--- Creating backup before reset ---')
  const backupOk = await backup()
  if (!backupOk) {
    console.log('Continuing without backup...\n')
  }

  // Execute reset
  console.log('--- Executing reset ---')

  const deleted = {}

  // 1. Transactions
  if (collections.includes('transactions')) {
    const r = await db.collection('transactions').deleteMany({})
    deleted.transactions = r.deletedCount
  }

  // 2. KYC records
  if (collections.includes('kycs')) {
    const r = await db.collection('kycs').deleteMany({})
    deleted.kycs = r.deletedCount
  }

  // 3. Expenses
  if (collections.includes('expenses')) {
    const r = await db.collection('expenses').deleteMany({})
    deleted.expenses = r.deletedCount
  }

  // 4. Notifications
  if (collections.includes('notifications')) {
    const r = await db.collection('notifications').deleteMany({})
    deleted.notifications = r.deletedCount
  }

  // 5. Profiles
  if (collections.includes('profiles')) {
    const r = await db.collection('profiles').deleteMany({})
    deleted.profiles = r.deletedCount
  }

  // 6. Delete non-admin wallets, reset admin wallets
  if (collections.includes('wallets')) {
    const r = await db.collection('wallets').deleteMany({ user: { $nin: adminIds } })
    deleted.nonAdminWallets = r.deletedCount

    if (adminWalletIds.length > 0) {
      await db.collection('wallets').updateMany(
        { _id: { $in: adminWalletIds } },
        { $set: { balanceSats: 0, balanceLAK: 0, lnbitsBaseSats: null } }
      )
    }
  }

  // 7. Delete regular users
  const r = await db.collection('users').deleteMany({ role: { $nin: ['admin', 'staff'] } })
  deleted.regularUsers = r.deletedCount

  // 8. Clean admin/staff fields (KYC + OTP)
  await db.collection('users').updateMany(
    { role: { $in: ['admin', 'staff'] } },
    {
      $set: { kycStatus: 'none', kyc: null },
      $unset: { resetPasswordOTP: '', resetPasswordOTPExpiry: '', resetPasswordOTPVerified: '' }
    }
  )

  // Summary
  console.log('\n=== Reset Complete ===')
  console.log(`  Transactions deleted:      ${deleted.transactions || 0}`)
  console.log(`  KYC records deleted:       ${deleted.kycs || 0}`)
  console.log(`  Expenses deleted:          ${deleted.expenses || 0}`)
  console.log(`  Notifications deleted:     ${deleted.notifications || 0}`)
  console.log(`  Profiles deleted:          ${deleted.profiles || 0}`)
  console.log(`  Regular users deleted:     ${deleted.regularUsers || 0}`)
  console.log(`  Non-admin wallets deleted: ${deleted.nonAdminWallets || 0}`)
  console.log(`  Admin wallets reset to 0:  ${adminWalletIds.length}`)

  const remaining = await db.collection('users').countDocuments()
  console.log(`\nTotal users remaining: ${remaining}`)

  await mongoose.disconnect()
  console.log('Disconnected')
}

resetAll().catch(err => {
  console.error('Error:', err)
  process.exit(1)
})
