package com.example.sample_c

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.util.AttributeSet
import android.view.KeyEvent
import android.view.View

class EmulatorView(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs)
{
    private val bitmap =
        Bitmap.createBitmap(
            640,
            344,
            Bitmap.Config.ARGB_8888
        )

    private val paint = Paint()

    init
    {
        NativeBridge.init(context.assets)

        isFocusable = true
        isFocusableInTouchMode = true

        requestFocus()

        post(
            object : Runnable
            {
                override fun run()
                {
                    invalidate()

                    postDelayed(
                        this,
                        16
                    )
                }
            }
        )
    }

    override fun onDraw(
        canvas: Canvas
    )
    {
        super.onDraw(canvas)

        val pixels =
            NativeBridge.render()

        bitmap.setPixels(
            pixels,
            0,
            640,
            0,
            0,
            640,
            344
        )

        canvas.drawBitmap(
            bitmap,
            null,
            Rect(
                0,
                0,
                width,
                height
            ),
            paint
        )
    }

    override fun onKeyDown(
        keyCode: Int,
        event: KeyEvent?
    ): Boolean
    {
        if (event?.isCtrlPressed == true)
        {
            when (keyCode)
            {
                KeyEvent.KEYCODE_C ->
                {
                    NativeBridge.keyPress(0x03)

                    invalidate()

                    return true
                }
            }
        }

        when (keyCode)
        {
            KeyEvent.KEYCODE_DPAD_UP -> {
                NativeBridge.keyPress(0x80)
                return true
            }

            KeyEvent.KEYCODE_DPAD_DOWN -> {
                NativeBridge.keyPress(0x81)
                return true
            }

            KeyEvent.KEYCODE_DPAD_RIGHT -> {
                NativeBridge.keyPress(0x82)
                return true
            }

            KeyEvent.KEYCODE_DPAD_LEFT -> {
                NativeBridge.keyPress(0x83)
                return true
            }

            KeyEvent.KEYCODE_ESCAPE ->
            {
                NativeBridge.keyPress(0x1B)

                invalidate()

                return true
            }

            KeyEvent.KEYCODE_DEL ->
            {
                NativeBridge.keyPress(0x08)

                invalidate()

                return true
            }

            KeyEvent.KEYCODE_ENTER ->
            {
                NativeBridge.keyPress(0x0D)

                invalidate()

                return true
            }
        }

        if (event != null)
        {
            val ch =
                event.unicodeChar

            if (ch != 0)
            {
                NativeBridge.keyPress(ch)

                invalidate()

                return true
            }
        }

        return super.onKeyDown(
            keyCode,
            event
        )
    }

    override fun performClick(): Boolean
    {
        super.performClick()

        return true
    }
}