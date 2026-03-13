const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const crypto = require('crypto');
const User = require('../models/User');

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        // ✅ ກວດສອບ email ກ່ອນໃຊ້
        const email = profile.emails?.[0]?.value;
        if (!email) {
          return done(new Error('No email found from Google profile'), false);
        }

        const normalizedEmail = email.toLowerCase(); // ✅ normalize ຄັ້ງດຽວ
        const name = profile.displayName;
        const googleId = profile.id;

        let user = await User.findOne({ email: normalizedEmail });

        if (user) {
          if (!user.googleId) {
            user.googleId = googleId;
            await user.save({ validateBeforeSave: false });
          }
          return done(null, user);
        }

        // ✅ ໃຊ້ normalizedEmail ຕອນ create ດ້ວຍ
        user = await User.create({
          name,
          email: normalizedEmail,
          googleId,
          password: crypto.randomBytes(32).toString('hex'),
          isGoogleAccount: true,
        });

        return done(null, user);
      } catch (error) {
        return done(error, false);
      }
    }
  )
);

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    // ✅ handle ກໍລະນີ user ຖືກລຶບໄປແລ້ວ
    if (!user) {
      return done(null, false);
    }
    done(null, user);
  } catch (error) {
    done(error, false);
  }
});

module.exports = passport;