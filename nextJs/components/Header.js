import { ConnectButton } from "web3uikit"
import Link from "next/link"

export default function Header() {
    return (
        <nav className="p-5 border-b-10 flex flex-row justify-between items-center bg-blue-800">
            <div className="flex items-center">
                <h1 className="font-orbitron py-4 px-4 font-bold text-4xl ml-10">UMATimeCard</h1>
            </div>
            <div className="flex flex-row items-center">
                <Link href="/" legacyBehavior>
                    <a className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 mr-4 px-4 rounded ml-auto">
                        Dashboard
                    </a>
                </Link>
                {/* <Link href="/your-nft" legacyBehavior>
                    <a className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 mr-4 px-4 rounded ml-auto">
                        Your NFT
                    </a>
                </Link> */}
                <ConnectButton moralisAuth={false} />
            </div>
        </nav>
    )
}
