const Notification = require('../models/Notification');

// ── Helper: ສ້າງ notification ໃນ transaction flow ──────────────────────────
exports.createNotification = async ({ userId, title, body, type, transactionId = null }) => {
    try {
        await Notification.create({ user: userId, title, body, type, transactionId });
    } catch (err) {
        console.error('Create notification error:', err.message);
    }
};

// ── GET /api/notifications ───────────────────────────────────────────────────
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.user._id })
            .sort({ createdAt: -1 })
            .limit(50);

        const unreadCount = await Notification.countDocuments({
            user: req.user._id,
            read: false,
        });

        return res.json({ success: true, notifications, unreadCount });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

// ── PUT /api/notifications/read-all ─────────────────────────────────────────
exports.markAllRead = async (req, res) => {
    try {
        await Notification.updateMany({ user: req.user._id, read: false }, { read: true });
        return res.json({ success: true });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

// ── PUT /api/notifications/:id/read ─────────────────────────────────────────
exports.markOneRead = async (req, res) => {
    try {
        await Notification.findOneAndUpdate(
            { _id: req.params.id, user: req.user._id },
            { read: true }
        );
        return res.json({ success: true });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};
