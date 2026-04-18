import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { USDCcontract, Market2contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".repMarket2");
const repayBtn = document.querySelector(".repayMarket2");

async function repayMarket2() {
    try {
        if (!userAddress) {
            await connectWallet();
        }

        if (!USDCcontract || !Market2contract) {
            alert("Сначала укажи адреса USDC и Market2 в init.js");
            return;
        }

        const amount = input.value.trim();
        if (!amount) {
            alert("Введи сумму погашения");
            return;
        }

        const inputWei = ethers.parseUnits(amount, 6);
        const approveTx = await USDCcontract.approve(await Market2contract.getAddress(), inputWei);
        await approveTx.wait();

        const tx = await Market2contract.repay(inputWei);
        await tx.wait();
        alert("Погашение долга в Market2 выполнено!");
    } catch (error) {
        console.log(error);
    }
}

repayBtn.addEventListener("click", (e) => {
    e.preventDefault();
    repayMarket2();
});
