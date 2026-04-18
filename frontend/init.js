import { ethers } from "./node_modules/ethers/dist/ethers.js";
import { DAI_ABI, PYUSD_ABI, USDC_ABI, UCD1_ABI, USDT_ABI, MARKET_ABI, VAULT_ABI, PRICE_ORACLE } from "./abi.js";

let signer;
let provider;
let userAddress;

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

function createContract(address, abi, currentSigner) {
    if (!address) {
        return null;
    }

    return new ethers.Contract(address, abi, currentSigner);
}

async function connectWallet() {
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();

    DAIcontract = createContract(DAIaddr, DAI_ABI, signer);
    PYUSDCcontract = createContract(PYUSDaddr, PYUSD_ABI, signer);
    USDCcontract = createContract(USDCaddr, USDC_ABI, signer);
    UCD1contract = createContract(UCD1addr, UCD1_ABI, signer);
    USDTcontract = createContract(USDTaddr, USDT_ABI, signer);

    Market1contract = createContract(Market1addr, MARKET_ABI, signer);
    Market2contract = createContract(Marketa2ddr, MARKET_ABI, signer);
    Market3contract = createContract(Market3addr, MARKET_ABI, signer);

    Vault1contract = createContract(Vault1addr, VAULT_ABI, signer);
    Vault2contract = createContract(Vault2addr, VAULT_ABI, signer);

    priceOracleContract = createContract(PriceOracleAddr, PRICE_ORACLE, signer);

    connectWalletBtn.textContent = `Подключен: ${userAddress}`;
    connectWalletBtn.disabled = true;
    return userAddress;
}

connectWalletBtn.addEventListener("click", connectWallet);
export {
    connectWallet,
    signer,
    provider,
    userAddress,
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
