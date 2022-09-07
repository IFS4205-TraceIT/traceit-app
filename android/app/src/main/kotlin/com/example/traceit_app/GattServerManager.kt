package com.example.traceit_app

import android.bluetooth.*
import android.bluetooth.BluetoothGatt.GATT_FAILURE
import android.bluetooth.BluetoothGatt.GATT_SUCCESS
import android.bluetooth.BluetoothGattCharacteristic.*
import android.content.Context
import io.flutter.Log
import java.util.*

class GattServerManager(context: Context) {
    private val TAG = "GATT Server";

    private val context: Context
    private var bluetoothManager: BluetoothManager
    private var bluetoothGattServer: BluetoothGattServer? = null

    private lateinit var gattCharacteristic: BluetoothGattCharacteristic
    private lateinit var gattService: BluetoothGattService

    init {
        this.context = context
        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        val writeDataPayload: MutableMap<String, ByteArray> = HashMap()
        val readPayloadMap: MutableMap<String, ByteArray> = HashMap()
        val deviceCharacteristicMap: MutableMap<String, UUID> = HashMap()

        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.i(TAG, "${device?.address} Connected to local GATT server")
                }

                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.i(TAG, "${device?.address} Disconnected from local GATT server.")
                    readPayloadMap.remove(device?.address)
                }

                else -> {
                    Log.i(TAG, "Connection status: $newState - ${device?.address}")
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic?
        ) {
            if (device == null) {
                Log.w(TAG, "No device")
            }

            // TODO: Check valid characteristic uuid

            device?.let {
                Log.i(TAG, "onCharacteristicReadRequest from ${device.address}")

                // check / update tempid is valid

                // Prepare peripheral payload
                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_SUCCESS,
                    0,
                    "test response payload".toByteArray()
                )
            }

        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            if (device == null) {
                Log.e(TAG, "Write stopped - no device")
            }

            device?.let {
                Log.i(
                    TAG,
                    "onCharacteristicWriteRequest - ${device.address} - preparedWrite: $preparedWrite"
                )

                Log.i(
                    TAG,
                    "onCharacteristicWriteRequest from ${device.address} - $requestId - $offset"
                )

                // if value is not null
                // save value
                deviceCharacteristicMap[device.address] = characteristic!!.uuid
                var valuePassed = ""
                value?.let {
                    valuePassed = String(value, Charsets.UTF_8)
                }
                Log.i(
                    TAG,
                    "onCharacteristicWriteRequest from ${device.address} - $valuePassed"
                )
                if (value != null) {
                    var dataBuffer = writeDataPayload[device.address]

                    if (dataBuffer == null) {
                        dataBuffer = ByteArray(0)
                    }

                    dataBuffer = dataBuffer.plus(value)
                    writeDataPayload[device.address] = dataBuffer

                    Log.i(
                        TAG,
                        "Accumulated characteristic: ${
                            String(
                                dataBuffer,
                                Charsets.UTF_8
                            )
                        }"
                    )

                    if (preparedWrite && responseNeeded) {
                        Log.i(TAG, "Sending response offset: ${dataBuffer.size}")
                        bluetoothGattServer?.sendResponse(
                            device,
                            requestId,
                            GATT_SUCCESS,
                            dataBuffer.size,
                            value
                        )
                    }
                }
            }
        }

        override fun onExecuteWrite(device: BluetoothDevice?, requestId: Int, execute: Boolean) {
            super.onExecuteWrite(device, requestId, execute)

            val data = writeDataPayload[device!!.address]

            data.let { dataBuffer ->

                if (dataBuffer != null) {
                    Log.i(
                        TAG,
                        "onExecuteWrite - $requestId- ${device.address} - ${
                            String(
                                dataBuffer,
                                Charsets.UTF_8
                            )
                        }"
                    )

                    // TODO: save data
//                    saveDataReceived(device)

                    bluetoothGattServer?.sendResponse(
                        device,
                        requestId,
                        GATT_SUCCESS,
                        0,
                        null
                    )

                } else {
                    bluetoothGattServer?.sendResponse(
                        device,
                        requestId,
                        GATT_FAILURE,
                        0,
                        null
                    )
                }
            }
        }

        fun saveDataReceived(device: BluetoothDevice) {
            // TODO: save data
        }
    }


    fun startGattServer(): Boolean {
        bluetoothGattServer = bluetoothManager.openGattServer(context, gattServerCallback)

        if (bluetoothGattServer == null) {
            return false
        }

        gattCharacteristic = BluetoothGattCharacteristic(
            UUID.randomUUID(), // TODO: Get UUID from flutter
            PROPERTY_READ or PROPERTY_WRITE,
            PERMISSION_READ or PERMISSION_WRITE
        )

        gattService = BluetoothGattService(
            UUID.randomUUID(), // TODO: Get UUID from flutter
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        gattService.addCharacteristic(gattCharacteristic)
        bluetoothGattServer!!.addService(gattService)

        return true
    }

    fun stopGattServer() {
        bluetoothGattServer!!.close()
        bluetoothGattServer = null
    }
}