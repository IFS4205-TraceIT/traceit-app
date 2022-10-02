package com.example.traceit_app

import android.bluetooth.*
import android.bluetooth.BluetoothGatt.GATT_FAILURE
import android.bluetooth.BluetoothGatt.GATT_SUCCESS
import android.bluetooth.BluetoothGattCharacteristic.*
import android.content.Context
import com.google.gson.Gson
import io.flutter.Log
import kotlinx.coroutines.runBlocking
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

    private var discoveredDevices: MutableSet<String> = mutableSetOf()

    init {
        this.context = context
        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {

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
                Log.w(TAG, "Read stopped - No device")
                return
            }

            // Send data only if not previously connected
            if (discoveredDevices.contains(device.address)) {
                Log.i(TAG, "Device ${device.address} already read")

                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_FAILURE,
                    0,
                    null
                )

                return
            }

            Log.i(TAG, "onCharacteristicReadRequest from ${device.address}")

            // Get valid temp id
            val tempId: String = runBlocking {
                TempIdMethodChannel.getTempId()
            }
            Log.i(TAG, "Temp ID: $tempId")

            // Prepare payload
            Log.i(TAG, "Sending response to ${device.address}")
            val payload: String = JSONObject()
                .put(
                    "id",
                    tempId
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
                Log.i(TAG, "Write stopped - no device")
                return
            }

            // Send data only if not previously connected
            if (discoveredDevices.contains(device.address)) {
                Log.i(TAG, "Device ${device.address} already written")

                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_FAILURE,
                    0,
                    null
                )

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

                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_FAILURE,
                    0,
                    null
                )

                return
            } else if (value == null) {
                Log.i(TAG, "Received empty characteristic write")

                bluetoothGattServer!!.sendResponse(
                    device,
                    requestId,
                    GATT_FAILURE,
                    0,
                    null
                )

                return
            }

            val receivedData = String(value, Charsets.UTF_8)
            Log.i(TAG, "Received write data: $receivedData")

            // Save write data\
            val dataToSave: Map<String, Any> = Gson().fromJson(
                receivedData, HashMap<String, Any>().javaClass
            )
            saveDataReceived(dataToSave)

            // Send acknowledgement response
            bluetoothGattServer?.sendResponse(
                device,
                requestId,
                GATT_SUCCESS,
                0,
                null
            )

            // Add device to discovered devices
            discoveredDevices.add(device.address)
        }

        fun saveDataReceived(writeData: Map<String, Any>) {
            Log.i(TAG, "Saving data received")
            StorageMethodChannel.writeCloseContact(
                writeData["id"] as String,
                (writeData["rssi"] as Double).toInt()
            )
        }
    }

    fun isRunning(): Boolean {
        return isRunning
    }

    fun startGattServer() {
        Log.i(TAG, "Starting GATT server")

        Log.i(TAG, "Reset discovered devices")
        discoveredDevices.clear()

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