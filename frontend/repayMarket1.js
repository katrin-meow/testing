import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { USDCcontract, Market1contract, connectWallet, userAddress } from "./init.js";

const input = document.querySelector(".repMarket1");
const repayBtn = document.querySelector(".repayMarket1");

async function repayMarket1() {
    try {
    
        const amount = input.value.trim();
    
        const inputWei = ethers.parseUnits(amount, 6);
        const approveTx = await USDCcontract.approve(await Market1contract.getAddress(), inputWei);
        await approveTx.wait();

        const tx = await Market1contract.repay(inputWei);
        await tx.wait();
        alert("Погашение долга в Market1 выполнено!");
    } catch (error) {
        console.log(error);
    }
}

repayBtn.addEventListener("click", (e) => {
    e.preventDefault();
    repayMarket1();
});
