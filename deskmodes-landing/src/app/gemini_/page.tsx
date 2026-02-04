'use client';

import Head from 'next/head';
import { useState } from 'react';

export default function GeminiLandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 font-sans transition-colors duration-300">
      <Head>
        <title>DeskModes - Manage Your Workspace</title>
        <meta name="description" content="DeskModes allows you to switch between different workspace environments instantly." />
      </Head>

      {/* Navigation */}
      <nav className="fixed w-full z-20 top-0 left-0 border-b border-gray-200 dark:border-gray-700 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md">
        <div className="max-w-screen-xl flex flex-wrap items-center justify-between mx-auto p-4">
          <a href="#" className="flex items-center space-x-3 rtl:space-x-reverse">
            <span className="self-center text-2xl font-bold whitespace-nowrap bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400">DeskModes</span>
          </a>
          <button 
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            type="button" 
            className="inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600" aria-controls="navbar-sticky" aria-expanded={isMenuOpen}>
            <span className="sr-only">Open main menu</span>
            <svg className="w-5 h-5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 17 14">
                <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M1 1h15M1 7h15M1 13h15"/>
            </svg>
          </button>
          <div className={`${isMenuOpen ? 'block' : 'hidden'} items-center justify-between w-full md:flex md:w-auto md:order-1`} id="navbar-sticky">
            <ul className="flex flex-col p-4 md:p-0 mt-4 font-medium border border-gray-100 rounded-lg bg-gray-50 md:flex-row md:space-x-8 md:mt-0 md:border-0 md:bg-transparent dark:bg-gray-800 md:dark:bg-transparent dark:border-gray-700">
              <li>
                <a href="#features" className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-blue-500 dark:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Features</a>
              </li>
              <li>
                <a href="#about" className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-blue-500 dark:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">About</a>
              </li>
              <li>
                <a href="#" className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 md:hover:bg-transparent md:hover:text-blue-700 md:p-0 md:dark:hover:text-blue-500 dark:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Contact</a>
              </li>
            </ul>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="bg-white dark:bg-gray-900 pt-32 pb-20 px-4 md:px-0">
        <div className="py-8 px-4 mx-auto max-w-screen-xl text-center lg:py-16">
            <h1 className="mb-4 text-4xl font-extrabold tracking-tight leading-none text-gray-900 md:text-5xl lg:text-6xl dark:text-white">Switch Contexts instantly.</h1>
            <p className="mb-8 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 lg:px-48 dark:text-gray-400">DeskModes optimizes your workflow by allowing you to create and switch between distinct desktop environments for Work, Development, Gaming, and more.</p>
            <div className="flex flex-col space-y-4 sm:flex-row sm:justify-center sm:space-y-0 sm:space-x-4">
                <a href="#" className="inline-flex justify-center items-center py-3 px-5 text-base font-medium text-center text-white rounded-lg bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 dark:focus:ring-blue-900 transition-colors">
                    Download for Mac
                    <svg className="w-3.5 h-3.5 ml-2" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 10">
                        <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M1 5h12m0 0L9 1m4 4L9 9"/>
                    </svg>
                </a>
                <a href="#" className="inline-flex justify-center items-center py-3 px-5 text-base font-medium text-center text-gray-900 rounded-lg border border-gray-300 hover:bg-gray-100 focus:ring-4 focus:ring-gray-100 dark:text-white dark:border-gray-700 dark:hover:bg-gray-700 dark:focus:ring-gray-800 transition-colors">
                    Learn more
                </a>
            </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="bg-gray-50 dark:bg-gray-800 py-20">
        <div className="max-w-screen-xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12 dark:text-white">Why DeskModes?</h2>
          <div className="grid md:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="bg-white dark:bg-gray-700 p-6 rounded-xl shadow-lg hover:shadow-xl transition-shadow duration-300">
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center mb-4 text-blue-600 dark:text-blue-300">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" /></svg>
              </div>
              <h3 className="text-xl font-bold mb-2 dark:text-white">App Grouping</h3>
              <p className="text-gray-600 dark:text-gray-300">Open only the apps you need for the task at hand. Keep distractions away and focus on what matters.</p>
            </div>
            {/* Feature 2 */}
            <div className="bg-white dark:bg-gray-700 p-6 rounded-xl shadow-lg hover:shadow-xl transition-shadow duration-300">
               <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-full flex items-center justify-center mb-4 text-purple-600 dark:text-purple-300">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              </div>
              <h3 className="text-xl font-bold mb-2 dark:text-white">One-Click Switch</h3>
              <p className="text-gray-600 dark:text-gray-300">Transition between modes in seconds via the menu bar or global hotkeys. No more manual setup.</p>
            </div>
            {/* Feature 3 */}
            <div className="bg-white dark:bg-gray-700 p-6 rounded-xl shadow-lg hover:shadow-xl transition-shadow duration-300">
               <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center mb-4 text-green-600 dark:text-green-300">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
              </div>
              <h3 className="text-xl font-bold mb-2 dark:text-white">Custom Configurations</h3>
              <p className="text-gray-600 dark:text-gray-300">Create unlimited modes. Assign specific apps, window layouts, and system settings to each mode.</p>
            </div>
          </div>
        </div>
      </section>

       {/* Footer */}
       <footer className="bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800">
        <div className="mx-auto w-full max-w-screen-xl p-4 py-6 lg:py-8">
            <div className="md:flex md:justify-between">
              <div className="mb-6 md:mb-0">
                  <a href="#" className="flex items-center">
                      <span className="self-center text-2xl font-semibold whitespace-nowrap dark:text-white">DeskModes</span>
                  </a>
              </div>
              <div className="grid grid-cols-2 gap-8 sm:gap-6 sm:grid-cols-3">
                  <div>
                      <h2 className="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Resources</h2>
                      <ul className="text-gray-500 dark:text-gray-400 font-medium">
                          <li className="mb-4">
                              <a href="#" className="hover:underline">Documentation</a>
                          </li>
                          <li>
                              <a href="#" className="hover:underline">Tailwind CSS</a>
                          </li>
                      </ul>
                  </div>
                  <div>
                      <h2 className="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Follow us</h2>
                      <ul className="text-gray-500 dark:text-gray-400 font-medium">
                          <li className="mb-4">
                              <a href="#" className="hover:underline ">Github</a>
                          </li>
                          <li>
                              <a href="#" className="hover:underline">Discord</a>
                          </li>
                      </ul>
                  </div>
                  <div>
                      <h2 className="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Legal</h2>
                      <ul className="text-gray-500 dark:text-gray-400 font-medium">
                          <li className="mb-4">
                              <a href="#" className="hover:underline">Privacy Policy</a>
                          </li>
                          <li>
                              <a href="#" className="hover:underline">Terms &amp; Conditions</a>
                          </li>
                      </ul>
                  </div>
              </div>
          </div>
          <hr className="my-6 border-gray-200 sm:mx-auto dark:border-gray-700 lg:my-8" />
          <div className="sm:flex sm:items-center sm:justify-between">
              <span className="text-sm text-gray-500 sm:text-center dark:text-gray-400">© 2026 <a href="#" className="hover:underline">DeskModes™</a>. All Rights Reserved.
              </span>
          </div>
        </div>
      </footer>
    </div>
  );
}
