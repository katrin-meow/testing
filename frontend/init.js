import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAI_ABI, PYUSD_ABI, USDC_ABI, UCD1_ABI, USDT_ABI, MARKET_ABI, VAULT_ABI, PRICE_ORACLE } from "./abi.js";

let signer;
let provider;

let DAIcontract;
let PYUSDCcontract;
let USDCcontract;
let UCD1contract;
let USDTcontract;

let Market1contract;
let Market2contract;
let Market3contract;

let Vault1contract;
let Vault2contract;

let priceOracleContract;

const DAIaddr = "";
const PYUSDaddr = "";
const USDCaddr = "";
const UCD1addr = "";
const USDTaddr = "";

const Market1addr = "";
const Marketa2ddr = "";
const Market3addr = "";

const Vault1addr = "";
const Vault2addr = "";

const PriceOracleAddr = "";

const connectWalletBtn = document.querySelector(".connectWalletBtn");
async function connectWallet(event) {
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();

    DAIcontract = new ethers.Contract(DAIaddr, DAI_ABI, signer);
    PYUSDCcontract = new ethers.Contract(PYUSDaddr, PYUSD_ABI, signer);
    USDCcontract = new ethers.Contract(USDCaddr, USDC_ABI, signer);
    UCD1contract = new ethers.Contract(UCD1addr, UCD1_ABI, signer);
    USDTcontract = new ethers.Contract(USDTaddr, USDT_ABI, signer);

    Market1contract = new ethers.Contract(Market1addr, MARKET_ABI, signer);
    Market2contract = new ethers.Contract(Marketa2ddr, MARKET_ABI, signer);
    Market3contract = new ethers.Contract(Market3addr, MARKET_ABI, signer);

    Vault1contract = new ethers.Contract(Vault1addr, VAULT_ABI, signer);
    Vault2contract = new ethers.Contract(Vault2addr, VAULT_ABI, signer);

    priceOracleContract = new ethers.Contract(PriceOracleAddr, PRICE_ORACLE, signer);

    const userAddr = await signer.getAddress();
    connectWalletBtn.textContent = `Подключен: ${userAddr}`;
    connectWalletBtn.disabled = true;

}
connectWalletBtn.addEventListener("click", connectWallet);
connectWallet();
export {
    signer,
    provider,
    DAIcontract,
    PYUSDCcontract,
    USDCcontract,
    UCD1contract,
    USDTcontract,
    Market1contract,
    Market2contract,
    Market3contract,
    Vault1contract,
    Vault2contract,
    priceOracleContract
};