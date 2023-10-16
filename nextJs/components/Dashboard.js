import { useEffect, useState } from "react"
import { useMoralis, useWeb3Contract } from "react-moralis"
import { useNotification } from "web3uikit"
import { ethers, BigNumber } from "ethers"
import { UMATimeCardEntranceAbi } from "../constants"
import Clock from "./Clock"

export default function Dashboard() {
    const { isWeb3Enabled, chainId: chainIdHex, account } = useMoralis()
    const chainId = parseInt(chainIdHex)
    const [fees, setFees] = useState("0")
    const [checkInOrOut, setcheckInOrOut] = useState("0")
    const dispatch = useNotification()
    const umaTimeCardEntranceAddr = "0x756C2eE52b51bEABD62f9D4ead9631829820E54A"

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

    const _checkIn = async function () {
        console.log(chainId)
        setcheckInOrOut(0)
        await send({ onSuccess: (tx) => handleSuccess(tx), onError: (error) => handleError(error) })
    }

    const _checkOut = async function () {
        setcheckInOrOut(1)
        await send({ onSuccess: (tx) => handleSuccess(tx), onError: (error) => handleError(error) })
    }

    const handleSuccess = async function (tx, str) {
        await tx.wait("1")
        handleNewNotification(tx)
    }

    const handleError = async function (error) {
        console.log(error)
    }

    const handleNewNotification = () => {
        dispatch({
            type: "info",
            message: "Transaction Complete!",
            title: "Transaction Notification",
            position: "topR",
            icon: "bell",
        })
    }

    async function updateUI() {
        try {
            const estimateFeesCall = (await estimateFees())[0]?.toString()
            setFees(estimateFeesCall)
        } catch (e) {}
    }

    useEffect(() => {
        const interval = setInterval(updateUI, 500)

        return () => {
            clearInterval(interval)
        }
    }, [isWeb3Enabled, account])

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
                    </div>
                    <Clock />
                </>
            ) : (
                <div className="ml-10 text-xl">Please connect to a wallet and switch to the Mentle test network. </div>
            )}
        </div>
    )
}
