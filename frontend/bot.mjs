import { readFile } from "node:fs/promises";
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider( "http://127.0.0.1:8545");

const keystorePath = process.env.KEYSTORE_PATH;//полный путь до пароля
const accountPassword = process.env.ACCOUNT_PASSWORD;

const keystoreJson = await readFile(keystorePath, "utf8");
const baseWallet = await ethers.Wallet.fromEncryptedJson(keystoreJson, accountPassword);
const wallet = baseWallet.connect(provider);
//function getBorrowers() external view returns (address[] memory) {
//     return borrowers;
// }

const ABI = [
    "function borrowers(uint256) view returns (address)",
    "function _isHealthy(address) view returns (bool)",
    "function liquidate(address) external",
];

const MARKETS = [
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005",
];

async function run() {
    for (const addr of MARKETS) {
        const market = new ethers.Contract(addr, ABI, wallet);

        for (let i = 0;  i+=1;) {
            let borrower;
            try {
                borrower = await market.borrowers(i);
            } catch {
                break;
            }

            const isHealthy = await market._isHealthy(borrower);
            if (isHealthy) {
                continue;
            }

            const tx = await market.liquidate(borrower);
            await tx.wait();
        }
    }
}

console.log("бот запущен");
await run();
setInterval(run, 10 * 60 * 1000);
