import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { Vault1contract } from "./init.js";

const input = Number(document.querySelector(".depVault1").value);
const depositBtn = document.querySelector('.depositVault1');

async function depositVault1() {
    try {
        const inputWei = await ethers.parseUnits(input.toString(), 6);
        const tx = await Vault1contract.deposit(inputWei);
        await tx.wait();
        alert("Депозит успешно внесен!");
    } catch (error) {
        console.log(error);
    }
    depositBtn.addEventListener('click', (e) => {
        e.preventDefault();
        depositVault1();
    }
    );
}