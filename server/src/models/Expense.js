// models/Expense.js
const mongoose = require('mongoose')

const expenseSchema = new mongoose.Schema({
  title:     { type: String, required: true },
  amount:    { type: Number, required: true },  // LAK
  category:  { type: String, enum: ['server', 'lnbits', 'salary', 'other'], default: 'other' },
  month:     { type: Number, required: true },  // 1-12
  year:      { type: Number, required: true },
  note:      { type: String },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true })

module.exports = mongoose.model('Expense', expenseSchema)