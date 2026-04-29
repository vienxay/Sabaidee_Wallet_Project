require('dotenv').config()

const express    = require('express')
const cors       = require('cors')
const helmet     = require('helmet')
const rateLimit  = require('express-rate-limit') // ✅ import ຄັ້ງດຽວ
const passport   = require('passport')
const path       = require('path')

const connectDB        = require('./src/config/db')
const adminRoutes      = require('./src/routes/adminRoutes')
const withdrawalRoutes = require('./src/routes/withdrawalRoutes')

require('./src/config/passport')

const app  = express()
const PORT = process.env.PORT || 3000

connectDB()

const { verifyEmailConnection } = require('./src/services/emailService')
verifyEmailConnection()

// ─── Security ─────────────────────────────────────────────────────────────
app.use(helmet())
app.set('trust proxy', 1)

// ─── CORS ─────────────────────────────────────────────────────────────────
app.use(cors({
    origin: process.env.NODE_ENV === 'production'
        ? process.env.FRONTEND_URL
        : [
            'http://localhost:3000',
            'http://localhost:8081',
            'http://10.0.2.2:3000',
            'http://10.0.2.2',
            'http://localhost:5173',
          ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
}))

// ─── Middlewares ──────────────────────────────────────────────────────────
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(passport.initialize())
app.use('/uploads', express.static(path.join(__dirname, 'uploads')))


// ─── Rate Limiters ────────────────────────────────────────────────────────

// ✅ General — 300 dev / 100 prod (ເພີ່ມຂຶ້ນ)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 300 : 100,
    message: { success: false, message: 'ຮ້ອງຂໍຫຼາຍເກີນໄປ, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ 15 ນາທີ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

// ✅ Auth — 20 dev / 10 prod
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 20 : 10,
    message: { success: false, message: 'ພະຍາຍາມເຂົ້າລະບົບຫຼາຍເກີນໄປ, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ 15 ນາທີ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

// ✅ Admin Dashboard — ເພີ່ມ limit ພິເສດ
const adminLimiter = rateLimit({
    windowMs: 1 * 60 * 1000,     // 1 ນາທີ
    max: process.env.NODE_ENV === 'development' ? 60 : 30,
    message: { success: false, message: 'ຮ້ອງຂໍຫຼາຍເກີນໄປ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

const paymentLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 30,
    message: { success: false, message: 'ມີການຈ່າຍເງິນຫຼາຍເກີນໄປ, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ 15 ນາທີ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

const kycLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 50 : 5,
    message: { success: false, message: 'ຍື່ນ KYC ຫຼາຍເກີນໄປ, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ 1 ຊົ່ວໂມງ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

const profileLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 60 : 20,
    message: { success: false, message: 'ຮ້ອງຂໍຫຼາຍເກີນໄປ, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ 15 ນາທີ' },
    standardHeaders: true,
    legacyHeaders:   false,
})

// ─── Apply Limiters ───────────────────────────────────────────────────────
app.use('/api/',                     limiter)
app.use('/api/admin',                adminLimiter)       // ✅ admin dashboard
app.use('/api/auth/login',           authLimiter)
app.use('/api/auth/register',        authLimiter)
app.use('/api/auth/forgot-password', authLimiter)
app.use('/api/payment/pay',          paymentLimiter)
app.use('/api/kyc/submit',           kycLimiter)
app.use('/api/profile',              profileLimiter)

// ─── Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth',         require('./src/routes/authRoutes'))
app.use('/api/wallet',       require('./src/routes/walletRoutes'))
app.use('/api/payment',      require('./src/routes/paymentRoutes'))
app.use('/api/transactions', require('./src/routes/transactionRoutes'))
app.use('/api/kyc',          require('./src/routes/kycRoutes'))
app.use('/api/withdrawal',   withdrawalRoutes)
app.use('/api/profile',      require('./src/routes/profileRoutes'))
app.use('/api/admin',        adminRoutes)

app.get('/favicon.ico', (req, res) => res.status(204).end())

// ─── Deep Links ───────────────────────────────────────────────────────────
app.get('/open/home', (req, res) => res.redirect('sabaidee://home'))
app.get('/open/kyc',  (req, res) => res.redirect('sabaidee://kyc'))

// ─── Root ─────────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
    res.json({ success: true, message: 'Sabaidee Wallet API is running 🚀' })
})


// ─── 404 ──────────────────────────────────────────────────────────────────
app.use((req, res, next) => {
    const error = new Error(`ບໍ່ພົບ API: ${req.method} ${req.originalUrl}`)
    error.status = 404
    next(error)
})

// ─── Error Handler ────────────────────────────────────────────────────────
app.use((err, req, res, next) => {
    if (res.headersSent) return next(err)
    const statusCode = err.status || err.statusCode || 500
    if (process.env.NODE_ENV === 'development') {
        console.error('Error:', err)
    } else {
        console.error('Error:', err.message)
    }
    res.status(statusCode).json({
        success: false,
        message: err.message || 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    })
})

// ─── Graceful Shutdown ────────────────────────────────────────────────────
const gracefulShutdown = (signal) => {
    console.log(`\n${signal} received. Shutting down gracefully...`)
    server.close(() => {
        console.log('HTTP server closed')
        process.exit(0)
    })
    setTimeout(() => {
        console.error('Forcing shutdown...')
        process.exit(1)
    }, 10000)
}

process.on('uncaughtException',  (err) => {
    console.error('Uncaught Exception:', err); process.exit(1)
})
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason); process.exit(1)
})
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('SIGINT',  () => gracefulShutdown('SIGINT'))

// ─── Start ────────────────────────────────────────────────────────────────
const server = app.listen(PORT, () => {
    console.log(`🚀 Server Running: Port ${PORT}`)
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`)
})

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`❌ Port ${PORT} ຖືກໃຊ້ງານແລ້ວ!`)
        process.exit(1)
    } else {
        console.error('Server Error:', err)
    }
})