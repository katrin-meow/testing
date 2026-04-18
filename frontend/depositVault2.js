import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { PYUSDCcontract, Vault2contract,  userAddress } from "./init.js";

const input = document.querySelector(".depVault2");
const depositBtn = document.querySelector(".depositVault2");

async function depositVault2() {
    try {

        const inputWei = ethers.parseUnits(input.toString(), 6);
        const approveTx = await PYUSDCcontract.approve(await Vault2contract.getAddress(), inputWei);
        await approveTx.wait();

        const tx = await Vault2contract.deposit(inputWei, userAddress);
        await tx.wait();
        alert("Депозит в Vault2 выполнен!");
    } catch (error) {
        console.log(error);
    }
}

depositBtn.addEventListener("click", (e) => {
    e.preventDefault();
    depositVault2();
});
