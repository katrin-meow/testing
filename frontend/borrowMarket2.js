import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Market2contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".borMarket2");
const borrowBtn = document.querySelector(".borrowMarket2");

async function borrowMarket2() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!Market2contract) {
            alert("Сначала укажи адрес Market2 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму займа");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);
        const tx = await Market2contract.borrow(inputWei);
        await tx.wait();
        alert("Заем из Market2 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

borrowBtn.addEventListener("click", (e) => {
    e.preventDefault();
    borrowMarket2();
});
