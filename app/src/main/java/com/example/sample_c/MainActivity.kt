package com.example.sample_c

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.EditText
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity()
{
    private var paused = false

    private var dasmMode = false

    override fun onCreate(
        savedInstanceState: Bundle?
    )
    {
        super.onCreate(savedInstanceState)

        setContentView(
            EmulatorView(this)
        )

        supportActionBar?.title =
            "RC2014"
    }

    override fun onCreateOptionsMenu(
        menu: Menu
    ): Boolean
    {
        buildMenu(menu)

        return true
    }

    private fun buildMenu(
        menu: Menu
    )
    {
        menu.clear()

        if (paused)
        {
            menu.add(0, 1, 0, "RUN")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 2, 0, "STEP")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 8, 0, "REG")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 9, 0, "DASM")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )
        }
        else
        {
            menu.add(0, 3, 0, "PAUS")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 4, 0, "BRK")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 5, 0, "ESC")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 6, 0, "BS")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )

            menu.add(0, 7, 0, "KBD")
                .setShowAsAction(
                    MenuItem.SHOW_AS_ACTION_ALWAYS
                )
        }
    }

    override fun onPrepareOptionsMenu(
        menu: Menu
    ): Boolean
    {
        buildMenu(menu)

        return true
    }

    override fun onOptionsItemSelected(
        item: MenuItem
    ): Boolean
    {
        when (item.itemId)
        {
            1 ->
            {
                NativeBridge.toggleRun()

                paused = false

                invalidateOptionsMenu()

                return true
            }

            2 ->
            {
                NativeBridge.step()

                return true
            }

            3 ->
            {
                NativeBridge.toggleRun()

                paused = true

                invalidateOptionsMenu()

                return true
            }

            4 ->
            {
                NativeBridge.keyPress(0x03)

                return true
            }

            5 ->
            {
                NativeBridge.keyPress(0x1B)

                return true
            }

            6 ->
            {
                NativeBridge.keyPress(0x08)

                return true
            }

            7 ->
            {
                val input =
                    EditText(this)

                AlertDialog.Builder(this)
                    .setTitle("Keyboard Input")
                    .setView(input)

                    .setPositiveButton("SEND")
                    { _, _ ->

                        input.text
                            .toString()
                            .forEach {
                                NativeBridge.keyPress(it.code)
                            }
                    }

                    .setNeutralButton("SEND+CR")
                    { _, _ ->

                        Thread {

                            val lines =
                                input.text
                                    .toString()
                                    .split(Regex("\\r?\\n"))

                            for (line in lines)
                            {
                                for (ch in line)
                                {
                                    NativeBridge.keyPress(ch.code)

                                    Thread.sleep(10)
                                }

                                NativeBridge.keyPress(0x0D)

                                Thread.sleep(1000)
                            }

                        }.start()
                    }

                    .setNegativeButton(
                        "CANCEL",
                        null
                    )
                    .show()

                return true
            }

            8 ->
            {
                dasmMode = false

                NativeBridge.setDebugMode(0)

                return true
            }

            9 ->
            {
                dasmMode = true

                NativeBridge.setDebugMode(1)

                return true
            }
        }

        return super.onOptionsItemSelected(
            item
        )
    }
}