import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Vault2contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".withVault2");
const withdrawBtn = document.querySelector(".withdrawVault2");

async function withdrawVault2() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!Vault2contract) {
            alert("Сначала укажи адрес Vault2 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму вывода");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);
        const tx = await Vault2contract.withdraw(inputWei, userAddress, userAddress);
        await tx.wait();
        alert("Вывод из Vault2 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

withdrawBtn.addEventListener("click", (e) => {
    e.preventDefault();
    withdrawVault2();
});
