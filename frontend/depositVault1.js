import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { USDCcontract, Vault1contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".depVault1");
const depositBtn = document.querySelector('.depositVault1');

async function depositVault1() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!USDCcontract || !Vault1contract) {
            alert("Сначала укажи адреса USDC и Vault1 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму депозита");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);

        const approveTx = await USDCcontract.approve(await Vault1contract.getAddress(), inputWei);
        await approveTx.wait();

        const tx = await Vault1contract.deposit(inputWei, userAddress);
        await tx.wait();
        alert("Депозит успешно внесен!");
    } catch (error) {
        console.log(error);
    }
}

depositBtn.addEventListener('click', (e) => {
    e.preventDefault();
    depositVault1();
});
