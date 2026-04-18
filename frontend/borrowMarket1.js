import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Market1contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".borMarket1");
const borrowBtn = document.querySelector(".borrowMarket1");

async function borrowMarket1() {
    try {
   

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму займа");
            return;
        }
      
        const inputWei = ethers.parseUnits(amount, 6);
        const tx = await Market1contract.borrow(inputWei);
        await tx.wait();
        alert("Заем из Market1 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

borrowBtn.addEventListener("click", (e) => {
    e.preventDefault();
    borrowMarket1();
});
