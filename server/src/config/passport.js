// Google OAuth 2.0 Strategy ສຳລັບ login ຜ່ານ Google
// ຂໍ້ຮຽກ .env: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_CALLBACK_URL
// Flow: Google redirect → callback → ກວດ/ສ້າງ user → return JWT
const passport    = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const crypto      = require('crypto');
const User        = require('../models/User');

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

        let user = await User.findOne({ email: normalizedEmail });

        if (user) {
          // user ມີຢູ່ແລ້ວ → ຕໍ່ Google ID ຖ້າຍັງບໍ່ມີ (ສຳລັບ user ທີ່ register ດ້ວຍ email ກ່ອນ)
          if (!user.googleId) {
            user.googleId = googleId;
            await user.save({ validateBeforeSave: false });
          }
          return done(null, user);
        }

        // user ໃໝ່ → ສ້າງ account ໂດຍ random password (Google account ບໍ່ໃຊ້ password login)
        user = await User.create({
          name,
          email:           normalizedEmail,
          googleId,
          password:        crypto.randomBytes(32).toString('hex'),
          isGoogleAccount: true,
        });

        return done(null, user);
      } catch (error) {
        return done(error, false);
      }
    }
  )
);

// serializeUser: ເກັບ user.id ໃນ session (ໃຊ້ ID ດຽວ ບໍ່ເກັບ object ທັງໝົດ)
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// deserializeUser: ດຶງ user ຈາກ DB ດ້ວຍ ID ທີ່ເກັບ session
// ຖ້າ user ຖືກລຶບ → return false (session valid ແຕ່ user ບໍ່ມີ)
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    if (!user) {
      return done(null, false);
    }
    done(null, user);
  } catch (error) {
    done(error, false);
  }
});

module.exports = passport;
