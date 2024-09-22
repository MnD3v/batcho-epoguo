"use client"
import { motion } from 'framer-motion'
import React, { useEffect, useState } from 'react'
import { useGlobalState } from '../contexts/GlobalStateContext'
import { usePathname } from 'next/navigation'

const FixedAppBar = ({ fixed }: { fixed?: boolean }) => {
    const { menuIsOpen, setMenuIsOpen } = useGlobalState();

    const [showAppBar, setShow] = useState(false)

    const pathName = usePathname()
    const [inNotHome, setInNotHome] = useState(false)
    if (pathName != '/') {
        setInNotHome(true)
    }


    useEffect(() => {
        const handleScroll = () => {
            if (window.scrollY > 180) {
                setShow(true)
            } else {
                setShow(false)
            }
        }
        window.addEventListener('scroll', handleScroll)
        return () => {
            window.removeEventListener('scroll', handleScroll)
        }
    }, [])

    return (
        <motion.div className={` fixed flex justify-center  text-black bg-orange-50  w-full shadow z-50`}
            initial={{ y: -200 }}
            animate={{ y: fixed == true ? 0 : showAppBar ? 0 : -200, }}

        >
            <div className='max w-full flex justify-between
             items-center
             py-6 px-4
             '>

                <a href="#"> <img src="/black-logo.png" alt="" className='h-12 md:h-20' />
                </a>
                <button
                    onClick={() => {

                        setMenuIsOpen((!menuIsOpen))
                        console.log(menuIsOpen)
                    }} className={`p-2 md:hidden ${menuIsOpen ? 'pointer-events-none' : 'pointer-events-auto'}`}>
                    <img src={"/icons/black-menu.png"} alt="" className='h-5 ' />
                </button>
                <ul className={`font-jost hidden md:flex items-center justify-center`}>
                    <li className="hover:text-orange-600 font-semibold border-l-[1px] border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#"}>Accueil</a></li>
                    <li className="hover:text-orange-600 font-semibold border-l-[1px] border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#formations"}>Formations</a></li>

                    <li className="hover:text-orange-600 font-semibold border-l-[1px] border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#a-propos"}>A Propos</a></li>
                    <li className="hover:text-orange-600 font-semibold border-l-[1px] border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#contact"}>Contact</a></li>
                </ul>
            </div>


        </motion.div>
    )
}

export default FixedAppBar