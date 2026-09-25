package com.example.sample_c

import android.content.res.AssetManager

object NativeBridge
{
    init
    {
        System.loadLibrary("sample_c")
    }

    external fun init(
        assetManager: AssetManager
    )

    external fun render(): IntArray

    external fun keyPress(
        ch: Int
    )

    external fun step()

    external fun toggleRun()

    external fun setDebugMode(
        mode: Int
    )
}