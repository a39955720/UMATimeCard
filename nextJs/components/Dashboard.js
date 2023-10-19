import { useEffect, useState } from "react"
import { useMoralis, useWeb3Contract } from "react-moralis"
import { useNotification } from "web3uikit"
import { ethers } from "ethers"
import { UMATimeCardEntranceAbi } from "../constants"
import { createClient } from "@layerzerolabs/scan-client"
import Link from "next/link"
import Clock from "./Clock"

export default function Dashboard() {
    const { isWeb3Enabled, chainId: chainIdHex, account } = useMoralis()
    const chainId = parseInt(chainIdHex)
    const [fees, setFees] = useState("0")
    const [checkInOrOut, setCheckInOrOut] = useState("0")
    const [error, setError] = useState()
    const [showModal, setShowModal] = useState(false)
    const [isDelivered, setDelivered] = useState(false)
    const [_message, setMessage] = useState("0")
    const [txHash, setTxHash] = useState("0")
    const dispatch = useNotification()
    const client = createClient("testnet")
    const umaTimeCardEntranceAddr = "0x756C2eE52b51bEABD62f9D4ead9631829820E54A"

    const networks = {
        mantle: {
            chainId: `0x${Number(5001).toString(16)}`,
            rpcUrls: ["https://rpc.testnet.mantle.xyz"],
        },
    }

    const {
        runContractFunction: send,
        isLoading,
        isFetching,
    } = useWeb3Contract({
        abi: UMATimeCardEntranceAbi,
        contractAddress: umaTimeCardEntranceAddr,
        functionName: "send",
        params: { checkInOrOut: checkInOrOut },
        msgValue: fees,
    })

    const { runContractFunction: estimateFees } = useWeb3Contract({
        abi: UMATimeCardEntranceAbi,
        contractAddress: umaTimeCardEntranceAddr,
        functionName: "estimateFees",
        params: {
            adapterParams: ethers.utils.solidityPack(["uint16", "uint256"], [1, 800000]),
            checkInOrOut: 1,
        },
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

    const _checkIn = async function () {
        setCheckInOrOut(0)
        await send({ onSuccess: (tx) => handleSuccess(tx), onError: (error) => handleError(error) })
    }

    const _checkOut = async function () {
        setCheckInOrOut(1)
        await send({ onSuccess: (tx) => handleSuccess(tx), onError: (error) => handleError(error) })
    }

    const handleSuccess = async function (tx) {
        await tx.wait("1")
        setTxHash(tx.hash)
        handleNewNotification(tx)
        setShowModal(true)
    }

    const handleError = async function (error) {
        console.log(error)
    }

    const handleNewNotification = (tx) => {
        dispatch({
            type: "info",
            message: tx.hash,
            title: "Transaction Notification",
            position: "topR",
            icon: "bell",
        })
    }

    async function updateUI() {
        try {
            const estimateFeesCall = (await estimateFees())[0]?.toString()
            setFees(estimateFeesCall)
            const { messages } = await client.getMessagesBySrcTxHash(txHash)
            setMessage(messages[0])
            if (_message.status == "DELIVERED") {
                setDelivered(true)
            }
        } catch (e) {}
    }

    useEffect(() => {
        const interval = setInterval(updateUI, 500)

        return () => {
            clearInterval(interval)
        }
    }, [isWeb3Enabled, account, txHash, _message])

    return (
        <div className="bg-gradient-to-br from-yellow-500 to-purple-500 flex flex-col min-h-screen">
            {isWeb3Enabled && chainId == "5001" ? (
                <>
                    <div className="p-20 flex flex-row justify-center items-center">
                        <button
                            className="bg-black hover:bg-blue-700 text-white font-bold py-8 px-16 rounded mr-20"
                            onClick={async function () {
                                await _checkIn()
                            }}
                            disabled={isLoading || isFetching}
                        >
                            {isLoading || isFetching ? (
                                <div className="animate-spin spinner-border h-8 w-8 border-b-2 rounded-full"></div>
                            ) : (
                                <span className="text-4xl font-orbitron">Check In</span>
                            )}
                        </button>
                        <button
                            className="bg-white hover:bg-blue-700 text-white font-bold py-8 px-16 rounded ml-20"
                            onClick={async function () {
                                await _checkOut()
                            }}
                            disabled={isLoading || isFetching}
                        >
                            {isLoading || isFetching ? (
                                <div className="animate-spin spinner-border h-8 w-8 border-b-2 rounded-full"></div>
                            ) : (
                                <span className="text-4xl font-orbitron text-black">Check Out</span>
                            )}
                        </button>
                        {showModal && (
                            <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
                                <div className="bg-green-400 p-5 rounded w-2/3 h-1/2">
                                    <div className="flex mt-10 flex-grow justify-between">
                                        <span className="bg-blue-600 text-white font-bold py-8 px-16 rounded-full ml-5 mr-10 break-words">
                                            Transaction successful
                                        </span>
                                        <div class="flex items-center">
                                            <div class="w-4 h-4 bg-transparent border-t-2 border-r-2 border-solid border-gray-500 transform rotate-45"></div>
                                        </div>
                                        {isDelivered ? (
                                            <div className="flex flex-grow justify-between">
                                                <span className="bg-blue-600 text-white font-bold py-8 px-16 rounded-full ml-10 mr-10 break-words">
                                                    In flight...
                                                </span>
                                                <div class="flex items-center">
                                                    <div class="w-4 h-4 bg-transparent border-t-2 border-r-2 border-solid border-gray-500 transform rotate-45"></div>
                                                </div>
                                                <span className="bg-blue-600 text-white font-bold py-8 px-16 rounded-full ml-10 break-words">
                                                    Delivered
                                                </span>
                                            </div>
                                        ) : (
                                            <div className="flex flex-grow">
                                                <span className="bg-blue-600 text-white font-bold py-8 px-16 rounded-full shadow-md animate-pulse ml-10 mr-10 break-words">
                                                    Sending message to Goerli...
                                                </span>
                                                <div class="flex items-center">
                                                    <div class="w-4 h-4 bg-transparent border-t-2 border-r-2 border-solid border-gray-500 transform rotate-45"></div>
                                                </div>
                                                <span className="bg-gray-400 text-white font-bold py-8 px-16 rounded-full ml-10 break-words">
                                                    Delivered
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                    <div className="text-lg mt-10 ml-10">
                                        Transaction hash:{" "}
                                        {_message && (
                                            <Link
                                                legacyBehavior
                                                href={`https://testnet.layerzeroscan.com/${_message.srcChainId}/address/${_message.srcUaAddress}/message/${_message.dstChainId}/address/${_message.dstUaAddress}/nonce/${_message.srcUaNonce}`}
                                            >
                                                <a style={{ color: "blue" }}>{txHash}</a>
                                            </Link>
                                        )}
                                    </div>
                                    <div className="flex mt-10 justify-center">
                                        <button
                                            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                                            onClick={() => {
                                                setShowModal(false)
                                                setDelivered(false)
                                                setTxHash(0)
                                                setMessage(0)
                                            }}
                                        >
                                            Close
                                        </button>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                    <Clock />
                </>
            ) : (
                <div className="flex flex-col items-start mt-10">
                    <div className="ml-10 text-xl">
                        Please connect to a wallet and switch to the Mentle test network.
                    </div>
                    <button
                        onClick={() => handleNetworkSwitch("mantle")}
                        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-10 mt-10"
                    >
                        Switch to Mantle testnet
                    </button>
                </div>
            )}
        </div>
    )
}
