import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Market3contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".borMarket3");
const borrowBtn = document.querySelector(".borrowMarket3");

async function borrowMarket3() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!Market3contract) {
            alert("Сначала укажи адрес Market3 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму займа");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);
        const tx = await Market3contract.borrow(inputWei);
        await tx.wait();
        alert("Заем из Market3 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

borrowBtn.addEventListener("click", (e) => {
    e.preventDefault();
    borrowMarket3();
});
