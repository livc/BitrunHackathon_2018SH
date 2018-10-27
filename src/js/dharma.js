import { Dharma, Web3 } from "@dharmaprotocol/dharma.js";

const hostII = "http://localhost:8545";
const providerII = new Web3.providers.HttpProvider(hostII);

const dharma = new Dharma(providerII);

const { LoanRequest } = Dharma.Types;

const loanRequest = await LoanRequest.create(dharma, {
    principalAmount: 1,
    principalToken: "WETH",
    collateralAmount: 20,
    collateralToken: "REP",
    interestRate: 3.5,
    termDuration: 3,
    termUnit: "months",
    expiresInDuration: 1,
    expiresInUnit: "weeks"
});

const debtorAddress = "0x3fa17c1f1a0ae2db269f0b572ca44b15bc83929a";

await loanRequest.signAsDebtor(debtorAddress);

const loanRequestData = loanRequest.toJSON();

const loanRequest = await LoanRequest.load(dharma, loanRequestData);

const creditor = "0x8d4f214a98765f1cb7faebbed490032b314eeb05";

loanRequest
    .assertFillable(creditor)
    .then(() => {
        console.log("The loan request is ready to be filled");
    })
    .catch((error) => {
        console.error(error);
    });

const txHash = await loanRequest.fillAsCreditor();
