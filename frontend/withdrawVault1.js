import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Vault1contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".withVault1");
const withdrawBtn = document.querySelector(".withdrawVault1");

async function withdrawVault1() {
    try {
        if (!userAddress) {
            await connectWallet();
        }
    

        const amount = input.value.trim();
    
        const inputWei = ethers.parseUnits(amount, 6);
        const tx = await Vault1contract.withdraw(inputWei, userAddress, userAddress);
        await tx.wait();
        alert("Вывод из Vault1 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

withdrawBtn.addEventListener("click", (e) => {
    e.preventDefault();
    withdrawVault1();
});
