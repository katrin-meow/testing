import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { USDCcontract, Market3contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".repMarket3");
const repayBtn = document.querySelector(".repayMarket3");

async function repayMarket3() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!USDCcontract || !Market3contract) {
            alert("Сначала укажи адреса USDC и Market3 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму погашения");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);
        const approveTx = await USDCcontract.approve(await Market3contract.getAddress(), inputWei);
        await approveTx.wait();

        const tx = await Market3contract.repay(inputWei);
        await tx.wait();
        alert("Погашение долга в Market3 выполнено!");
    } catch (error) {
        console.log(error);
    }
}

repayBtn.addEventListener("click", (e) => {
    e.preventDefault();
    repayMarket3();
});
