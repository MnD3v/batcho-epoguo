import React from 'react'

const Equipe = () => {
    const membres = [{ image: "/vice.jpg", poste: "PDG", nom: "Nom du Vice KERIM" }, { image: "/vice.jpg", poste: "Vice Président", nom: "Nom du Vice" },]
    return (
        <div className='flex justify-center'>
            <div className='max my-10'>
                <h1 className=' my-6 text-center text-2xl md:text-4xl'>Notre Equipe</h1>
                <div className='flex flex-wrap justify-center gap-3'>
                    {
                        membres.map((element) => (
                            <div key={element.poste} className='w-72 border '>
                                <img src={element.image} alt="" className='w-full h-56 object-cover' />
                                <div className='p-5'>
                                    <p className='text-orange-600 font-semibold'> {element.poste}</p>
                                    <p className='font-bricolage font-bold text-lg'>{element.nom}</p>
                                </div>
                            </div>
                        )
                        )
                    }
                </div>
            </div>
        </div>
    )
}

export default Equipe