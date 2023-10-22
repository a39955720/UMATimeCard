import { useEffect, useState } from "react"
import { useMoralis, useWeb3Contract } from "react-moralis"
import { UMATimeCardAbi } from "../constants"

export default function AttendanceRecord() {
    const { isWeb3Enabled, chainId: chainIdHex, account } = useMoralis()
    const chainId = parseInt(chainIdHex)
    const [error, setError] = useState()
    const [checkInData, setCheckInData] = useState("0")
    const [checkOutData, setCheckOutData] = useState("0")
    const umaTimeCardAddr = "0x870077211130d3279a3750Efae9deEFAD86B8f3E"

    const networks = {
        goerli: {
            chainId: `0x${Number(5).toString(16)}`,
            chainName: "Goerli",
            nativeCurrency: {
                name: "Goerli",
                symbol: "ETH",
                decimals: 18,
            },
            rpcUrls: ["https://rpc.ankr.com/eth_goerli"],
            blockExplorerUrls: ["https://goerli.etherscan.io"],
        },
    }

    const { runContractFunction: getCheckInData } = useWeb3Contract({
        abi: UMATimeCardAbi,
        contractAddress: umaTimeCardAddr,
        functionName: "getCheckInData",
        params: { employee: account },
    })

    const { runContractFunction: getCheckOutData } = useWeb3Contract({
        abi: UMATimeCardAbi,
        contractAddress: umaTimeCardAddr,
        functionName: "getCheckOutData",
        params: { employee: account },
    })

    const changeNetwork = async ({ networkName, setError }) => {
        try {
            if (!window.ethereum) throw new Error("No crypto wallet found")
            await window.ethereum.request({
                method: "wallet_addEthereumChain",
                params: [
                    {
                        ...networks[networkName],
                    },
                ],
            })
        } catch (err) {
            setError(err.message)
            console.log(error)
        }
    }

    const handleNetworkSwitch = async (networkName) => {
        setError()
        await changeNetwork({ networkName, setError })
    }

    const diplayCheckInTime = () => {
        const results = []
        try {
            const _length = checkInData.length
            for (var i = 0; i < _length; i++) {
                const timestamp = checkInData[i][1] * 1000
                const date = new Date(timestamp)
                const year = date.getFullYear()
                const month = (date.getMonth() + 1).toString().padStart(2, "0")
                const day = date.getDate().toString().padStart(2, "0")
                const hours = date.getHours().toString().padStart(2, "0")
                const minutes = date.getMinutes().toString().padStart(2, "0")
                const seconds = date.getSeconds().toString().padStart(2, "0")
                if (year == 1970) {
                    const formattedTime = "Disputed"
                    results.push(
                        <div className="text-xl text-center text-white" key={i}>
                            <p>{formattedTime}</p>
                        </div>,
                    )
                } else {
                    const formattedTime = `${month}-${day} ${hours}:${minutes}:${seconds}`
                    results.push(
                        <div className="text-xl text-center text-white" key={i}>
                            <p>{formattedTime}</p>
                        </div>,
                    )
                }
            }
            return results
        } catch (e) {}
    }

    const diplayCheckOutTime = () => {
        const results = []
        try {
            const _length = checkOutData.length
            for (var i = 0; i < _length; i++) {
                const timestamp = checkOutData[i][1] * 1000
                const date = new Date(timestamp)
                const year = date.getFullYear()
                const month = (date.getMonth() + 1).toString().padStart(2, "0")
                const day = date.getDate().toString().padStart(2, "0")
                const hours = date.getHours().toString().padStart(2, "0")
                const minutes = date.getMinutes().toString().padStart(2, "0")
                const seconds = date.getSeconds().toString().padStart(2, "0")
                const formattedTime = `${month}-${day} ${hours}:${minutes}:${seconds}`

                if (year == 1970) {
                    const formattedTime = "Disputed"
                    results.push(
                        <div className="text-xl text-center text-black" key={i}>
                            <p>{formattedTime}</p>
                        </div>,
                    )
                } else {
                    const formattedTime = `${month}-${day} ${hours}:${minutes}:${seconds}`
                    results.push(
                        <div className="text-xl text-center text-black" key={i}>
                            <p>{formattedTime}</p>
                        </div>,
                    )
                }
            }
            return results
        } catch (e) {}
    }

    async function updateUI() {
        const getCheckInDataFromCall = await getCheckInData()
        const getCheckOutDataFromCall = await getCheckOutData()
        setCheckInData(getCheckInDataFromCall)
        setCheckOutData(getCheckOutDataFromCall)
    }

    useEffect(() => {
        const interval = setInterval(updateUI, 500)
        return () => {
            clearInterval(interval)
        }
    }, [isWeb3Enabled, account])

    return (
        <div className="bg-gradient-to-br from-yellow-500 to-purple-500 flex flex-col min-h-screen">
            {isWeb3Enabled && chainId == "5" ? (
                <div className="flex justify-center h-screen mt-10 mb-10">
                    <div className="bg-black rounded shadow w-1/4 mr-20 min-h-screen overflow-y-hidden">
                        <div className="flex-grow"></div>
                        <div className="text-3xl text-center text-white">
                            <p>Check In Time:</p>
                        </div>
                        <div className="mt-5">{diplayCheckInTime()}</div>
                        <div className="flex-grow"></div>
                    </div>
                    <div className="bg-white rounded shadow w-1/4 ml-20 min-h-screen overflow-y-hidden">
                        <div className="flex-grow"></div>
                        <div className="text-3xl text-center text-black">
                            <p>Check Out Time:</p>
                        </div>
                        <div className="mt-5">{diplayCheckOutTime()}</div>
                        <div className="flex-grow"></div>
                    </div>
                </div>
            ) : (
                <div className="flex flex-col items-start mt-10">
                    <div className="ml-10 text-xl">
                        Please connect to a wallet and switch to the Goerli test network.
                    </div>
                    <button
                        onClick={() => handleNetworkSwitch("goerli")}
                        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-10 mt-10"
                    >
                        Switch to Goerli testnet
                    </button>
                </div>
            )}
        </div>
    )
}
