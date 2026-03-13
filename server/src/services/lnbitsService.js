// server/src/services/lnbitsService.js
const axios = require('axios'); // ✅ ເພີ່ມບ່ອນນີ້

const LNBITS_URL = process.env.LNBITS_URL;
const LNBITS_ADMIN_KEY = process.env.LNBITS_ADMIN_KEY;

const lnbitsService = {
  createWallet: async (userName) => {
    // 1. ກວດສອບກ່ອນວ່າ URL ແລະ Key ມີຄ່າບໍ່
    if (!process.env.LNBITS_URL || !process.env.LNBITS_ADMIN_KEY) {
      throw new Error('LNbits configuration is missing (URL or Admin Key)');
    }

    const url = `${process.env.LNBITS_URL.replace(/\/$/, "")}/usermanager/api/v1/users`;
    
    const payload = { 
      user_name: userName,
      wallet_name: `Sabaidee_${userName}`,
      admin_id: process.env.LNBITS_USER_ID 
    };

    try {
      const response = await axios.post(url, payload, {
        headers: {
          'X-Api-Key': process.env.LNBITS_ADMIN_KEY,
          'Content-Type': 'application/json'
        }
      });

      // ກວດສອບໂຄງສ້າງ Response ທີ່ LNbits ສົ່ງມາ
      if (!response.data || !response.data.wallets || response.data.wallets.length === 0) {
        throw new Error('LNbits created user but no wallet was returned');
      }

      const newWallet = response.data.wallets[0];

      return {
        lnbitsUserId: response.data.id,
        walletId: newWallet.id,
        adminKey: newWallet.adminkey,
        invoiceKey: newWallet.inkey
      };
    } catch (error) {
      // ສົ່ງ Error ທີ່ລະອຽດອອກໄປໃຫ້ Controller
      const errorDetail = error.response?.data?.detail || error.message;
      console.error('❌ LNbits Service Error:', errorDetail);
      throw new Error(errorDetail); 
    }
  }
};

module.exports = lnbitsService;