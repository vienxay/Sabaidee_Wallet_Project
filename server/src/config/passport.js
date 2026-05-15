// Google OAuth 2.0 Strategy ສຳລັບ login ຜ່ານ Google
// ຂໍ້ຮຽກ .env: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_CALLBACK_URL
// Flow: Google redirect → callback → ກວດ/ສ້າງ user (+wallet) → return JWT
const passport       = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const crypto         = require('crypto');
const User           = require('../models/User');
const Wallet         = require('../models/Wallet');
const lnbits         = require('../services/lnbitsService');

passport.use(
  new GoogleStrategy(
    {
      clientID:     process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL:  process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails?.[0]?.value;
        if (!email) {
          return done(new Error('No email found from Google profile'), false);
        }

        const normalizedEmail = email.toLowerCase();
        const name     = profile.displayName;
        const googleId = profile.id;

        // ─── user ມີຢູ່ແລ້ວ ─────────────────────────────────────────────
        let user = await User.findOne({ email: normalizedEmail });
        if (user) {
          // ຕໍ່ Google ID ຖ້າ user ເຄີຍ register ດ້ວຍ email ກ່ອນ
          if (!user.googleId) {
            user.googleId = googleId;
            await user.save({ validateBeforeSave: false });
          }

          // ກວດວ່າ user ນີ້ມີ wallet ແລ້ວຫຼືບໍ່ — ຖ້າບໍ່ມີ ສ້າງໃຫ້
          const existingWallet = await Wallet.findOne({ user: user._id });
          if (!existingWallet) {
            await _createWalletForUser(user, name);
          }

          return done(null, user);
        }

        // ─── user ໃໝ່ ────────────────────────────────────────────────────
        // ສ້າງ account + LNBits wallet ພ້ອມກັນ
        let walletResult;
        try {
          walletResult = await lnbits.createWallet(name);
          if (!walletResult?.walletId || !walletResult?.adminKey || !walletResult?.invoiceKey) {
            throw new Error('LNbits response incomplete');
          }
        } catch (walletErr) {
          console.error('❌ LNbits wallet creation failed (Google):', walletErr.message);
          return done(new Error('ບໍ່ສາມາດສ້າງ Wallet ໄດ້'), false);
        }

        // ສ້າງ user
        user = await User.create({
          name,
          email:           normalizedEmail,
          googleId,
          password:        crypto.randomBytes(32).toString('hex'),
          isGoogleAccount: true,
        });

        // ສ້າງ wallet ແລ້ວ link ຫາ user
        try {
          const wallet = await Wallet.create({
            user:       user._id,
            walletId:   walletResult.walletId,
            walletName: name,
            adminKey:   walletResult.adminKey,
            invoiceKey: walletResult.invoiceKey,
          });
          user.wallet = wallet._id;
          await user.save({ validateBeforeSave: false });
        } catch (dbErr) {
          // rollback: ລຶບ user ແລະ LNBits wallet ຖ້າ DB ມີ error
          console.error('❌ DB error saving wallet (Google):', dbErr.message);
          await User.findByIdAndDelete(user._id).catch(() => {});
          try { await lnbits.deleteWallet(walletResult.walletId); } catch (_) {}
          return done(new Error('ເກີດຂໍ້ຜິດພາດໃນການສ້າງ Wallet'), false);
        }

        return done(null, user);
      } catch (error) {
        console.error('❌ Google OAuth error:', error);
        return done(error, false);
      }
    }
  )
);

// ─── Helper ──────────────────────────────────────────────────────────────────
// ສ້າງ wallet ໃຫ້ user ທີ່ login Google ຄັ້ງທຳອິດ ແຕ່ຍັງບໍ່ມີ wallet
async function _createWalletForUser(user, name) {
  try {
    const walletResult = await lnbits.createWallet(name || user.name);
    if (!walletResult?.walletId) return;

    const wallet = await Wallet.create({
      user:       user._id,
      walletId:   walletResult.walletId,
      walletName: name || user.name,
      adminKey:   walletResult.adminKey,
      invoiceKey: walletResult.invoiceKey,
    });
    user.wallet = wallet._id;
    await user.save({ validateBeforeSave: false });
    console.log('✅ Wallet created for existing Google user:', user.email);
  } catch (err) {
    console.error('❌ Failed to create wallet for Google user:', err.message);
  }
}

// serializeUser: ເກັບ user.id ໃນ session
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// deserializeUser: ດຶງ user ຈາກ DB, ຖ້າຖືກລຶບ → return false
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    if (!user) return done(null, false);
    done(null, user);
  } catch (error) {
    done(error, false);
  }
});

module.exports = passport;
