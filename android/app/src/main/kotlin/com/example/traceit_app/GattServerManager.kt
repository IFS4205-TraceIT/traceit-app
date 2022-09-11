package com.example.traceit_app

import android.bluetooth.*
import android.bluetooth.BluetoothGatt.GATT_SUCCESS
import android.bluetooth.BluetoothGattCharacteristic.*
import android.content.Context
import com.google.gson.Gson
import io.flutter.Log
import org.json.JSONObject
import java.util.*

class GattServerManager(context: Context) {
    private val TAG: String = "GATT Server"
    private val SERVICE_UUID = UUID.fromString("bf27730d-860a-4e09-889c-2d8b6a9e0fe7")
    private val CHARACTERISTIC_UUID = UUID.fromString("7f20e8d6-b4f8-4148-8bfa-4ce6b0e270ea")

    private val context: Context
    private var bluetoothManager: BluetoothManager
    private var bluetoothGattServer: BluetoothGattServer? = null

    private lateinit var gattCharacteristic: BluetoothGattCharacteristic
    private lateinit var gattService: BluetoothGattService
    private var isRunning: Boolean = false

    init {
        this.context = context
        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        val writeDataPayload: MutableMap<String, ByteArray> = HashMap()
        val readPayloadMap: MutableMap<String, ByteArray> = HashMap()
        val deviceCharacteristicMap: MutableMap<String, UUID> = HashMap()

        override fun onMtuChanged(device: BluetoothDevice?, mtu: Int) {
            super.onMtuChanged(device, mtu)
            Log.i(TAG, "${device?.address} Requested MTU: $mtu")
        }

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

                // TODO: check / update tempid is valid through flutter method channel

                // TODO: Prepare payload
                val payload: String = JSONObject()
                    .put(
                        "id",
                        "4qS6+bFwTVhFNLeme/N2DMkAN2l6NgtbCELmPOict0/l0PmmGpkNliB8RicVjEZxWxtjFofUUNZCkUJrbEYAqyA1t7zCQGmfHQPEO5+M2VBeRJCOgEmeVeQE97FKFtvTVA=="
                    )
                    .toString(0)
                    .replace("[\n\r]", "")
                Log.i(TAG, payload)

                // Send response
                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_SUCCESS,
                    0,
                    payload.toByteArray()
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
                return
            }

            Log.i(
                TAG,
                "onCharacteristicWriteRequest - ${device.address} - preparedWrite: $preparedWrite"
            )

            Log.i(
                TAG,
                "onCharacteristicWriteRequest from ${device.address} - $requestId - $offset"
            )

            if (characteristic!!.uuid != CHARACTERISTIC_UUID) {
                Log.i(TAG, "Characteristic UUID mismatch")
                return
            } else if (value == null) {
                Log.i(TAG, "Received empty characteristic write")
                return
            }

            val receivedData = String(value, Charsets.UTF_8)
            Log.i(TAG, "Received write data: $receivedData")

            val writeData: Map<String, Any> = Gson().fromJson(
                receivedData, HashMap<String, Any>().javaClass
            )

            // TODO: save write data

            // Send acknowledgement response
            bluetoothGattServer?.sendResponse(
                device,
                requestId,
                GATT_SUCCESS,
                0,
                null
            )
        }

        fun saveDataReceived(device: BluetoothDevice) {
            // TODO: Create flutter method channel to save data
        }
    }

    fun isRunning(): Boolean {
        return isRunning
    }

    fun startGattServer() {
        Log.i(TAG, "Starting GATT server")

        if (bluetoothGattServer is BluetoothGattServer) {
            Log.i(TAG, "GATT server not started. GATT server already running")
            return
        }

        bluetoothGattServer = bluetoothManager.openGattServer(context, gattServerCallback)

        if (bluetoothGattServer == null) {
            Log.e(TAG, "GATT server not started")
            return
        }

        isRunning = true

        gattCharacteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            PROPERTY_READ or PROPERTY_WRITE,
            PERMISSION_READ or PERMISSION_WRITE
        )

        gattService = BluetoothGattService(
            SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        gattService.addCharacteristic(gattCharacteristic)
        bluetoothGattServer!!.addService(gattService)

        Log.i(TAG, "Started GATT server")
        Log.i(TAG, "Service UUID: $SERVICE_UUID")
        Log.i(TAG, "Characteristic UUID: $CHARACTERISTIC_UUID")
    }

    fun stopGattServer() {
        Log.i(TAG, "Stopping GATT server")

        if (bluetoothGattServer == null) {
            Log.i(TAG, "GATT server not stopped. No instance of GATT server")
            return
        }

        isRunning = false

        bluetoothGattServer!!.close()
        bluetoothGattServer = null

        Log.i(TAG, "Stopped GATT server")
    }
}