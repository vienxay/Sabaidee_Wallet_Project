/**
 * Reset all data in db_SabaideeWallet
 * - Keep admin/staff accounts (role: admin, staff)
 * - Delete all regular users, transactions, wallets, KYC, expenses, notifications, profiles
 * - Reset admin wallets to 0 balance
 *
 * Usage: node src/scripts/reset_all_data.js
 */
require('dotenv').config()
const mongoose = require('mongoose')

async function resetAll() {
  if (!process.env.MONGO_URI) {
    console.error('MONGO_URI not found in .env')
    process.exit(1)
  }

  await mongoose.connect(process.env.MONGO_URI)
  console.log('Connected to MongoDB')

  const db = mongoose.connection.db

  const collections = await db.listCollections().toArray()
  const collectionNames = collections.map(c => c.name)
  console.log('Collections found:', collectionNames.join(', '))

  // 1. Delete all transactions
  if (collectionNames.includes('transactions')) {
    const r = await db.collection('transactions').deleteMany({})
    console.log(`Transactions deleted: ${r.deletedCount}`)
  }

  // 2. Delete all KYC records
  if (collectionNames.includes('kycs')) {
    const r = await db.collection('kycs').deleteMany({})
    console.log(`KYC records deleted: ${r.deletedCount}`)
  }

  // 3. Delete all expenses
  if (collectionNames.includes('expenses')) {
    const r = await db.collection('expenses').deleteMany({})
    console.log(`Expenses deleted: ${r.deletedCount}`)
  }

  // 4. Delete all notifications
  if (collectionNames.includes('notifications')) {
    const r = await db.collection('notifications').deleteMany({})
    console.log(`Notifications deleted: ${r.deletedCount}`)
  }

  // 5. Delete all profiles
  if (collectionNames.includes('profiles')) {
    const r = await db.collection('profiles').deleteMany({})
    console.log(`Profiles deleted: ${r.deletedCount}`)
  }

  // 6. Delete wallets of regular users, reset admin/staff wallets to 0
  const adminUsers = await db.collection('users').find(
    { role: { $in: ['admin', 'staff'] } },
    { projection: { _id: 1, name: 1, role: 1, wallet: 1 } }
  ).toArray()

  const adminIds = adminUsers.map(u => u._id)
  const adminWalletIds = adminUsers.map(u => u.wallet).filter(Boolean)

  if (collectionNames.includes('wallets')) {
    // Delete non-admin wallets
    const r = await db.collection('wallets').deleteMany({
      user: { $nin: adminIds }
    })
    console.log(`Non-admin wallets deleted: ${r.deletedCount}`)

    // Reset admin wallets to 0
    if (adminWalletIds.length > 0) {
      const r2 = await db.collection('wallets').updateMany(
        { _id: { $in: adminWalletIds } },
        { $set: { balanceSats: 0, balanceLAK: 0, lnbitsBaseSats: null } }
      )
      console.log(`Admin wallets reset to 0: ${r2.modifiedCount}`)
    }
  }

  // 7. Delete all regular users (keep admin/staff)
  const r = await db.collection('users').deleteMany({
    role: { $nin: ['admin', 'staff'] }
  })
  console.log(`Regular users deleted: ${r.deletedCount}`)

  // 8. Reset admin/staff kycStatus
  await db.collection('users').updateMany(
    { role: { $in: ['admin', 'staff'] } },
    { $set: { kycStatus: 'none', kyc: null } }
  )

  // Summary
  console.log('\n=== Reset Complete ===')
  console.log('Kept accounts:')
  adminUsers.forEach(u => {
    console.log(`  - ${u.name} (${u.role})`)
  })

  const remaining = await db.collection('users').countDocuments()
  console.log(`Total users remaining: ${remaining}`)

  await mongoose.disconnect()
  console.log('Disconnected')
}

resetAll().catch(err => {
  console.error('Error:', err)
  process.exit(1)
})
