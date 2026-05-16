import time

import hid
import psutil

VENDOR_ID = 0x3633  # DeepCool's Vendor ID
PRODUCT_ID = 0  # to be updated in setup
SENSOR = ""  # to be updated in setup
SHOW_TEMP = True
SHOW_UTIL = True
INTERVAL = 2


def get_bar_value(input_value):
    return (input_value - 1) // 10 + 1


def get_data(value=0, mode="util"):
    base_data = [16] + [0 for i in range(64 - 1)]
    numbers = [int(char) for char in str(value)]
    base_data[2] = get_bar_value(value)
    if mode == "util":
        base_data[1] = 76
    elif mode == "start":
        base_data[1] = 170
        return base_data
    elif mode == "temp":
        base_data[1] = 19

    if len(numbers) == 1:
        base_data[5] = numbers[0]
    elif len(numbers) == 2:
        base_data[4] = numbers[0]
        base_data[5] = numbers[1]
    elif len(numbers) == 3:
        base_data[3] = numbers[0]
        base_data[4] = numbers[1]
        base_data[5] = numbers[2]
    elif len(numbers) == 4:
        base_data[3] = numbers[0]
        base_data[4] = numbers[1]
        base_data[5] = numbers[2]
        base_data[6] = numbers[3]

    return base_data


def get_cpu_temperature(label="CPU"):
    sensors = psutil.sensors_temperatures()
    for sensor_label, sensor_list in sensors.items():
        for sensor in sensor_list:
            if sensor.label == label:
                return sensor.current

    return 0


def get_temperature():
    try:
        # Get sensor data with proper error checking
        sensor_data = psutil.sensors_temperatures().get(SENSOR)
        
        if not sensor_data:
            print(f"Warning: {SENSOR} sensor not found or has no readings")
            return get_cpu_temperature()
        
        # Get the Tctl temperature specifically if available
        for reading in sensor_data:
            if reading.label == 'Tctl':
                temp = round(reading.current)
                break
        else:
            # Fall back to first reading if Tctl not found
            temp = round(sensor_data[0].current)
            print(f"Using {sensor_data[0].label} instead of Tctl")
        
        return get_data(value=temp, mode="temp")
        
    except (IndexError, AttributeError) as e:
        print(f"Error reading {SENSOR} sensor: {e}")
        return get_cpu_temperature()
    except Exception as e:
        print(f"Unexpected error: {e}")
        return get_cpu_temperature()


def get_utils():
    utils = round(psutil.cpu_percent())
    return get_data(value=utils, mode="util")


try:
    h = hid.device()
    h.open(VENDOR_ID, PRODUCT_ID)
    h.set_nonblocking(1)
    h.write(get_data(mode="start"))
    while True:
        h.set_nonblocking(1)
        if SHOW_TEMP:
            h.write(get_temperature())
            time.sleep(INTERVAL)

        if SHOW_UTIL:
            h.write(get_utils())
            time.sleep(INTERVAL)
except IOError as error:
    print(error)
    print(
        "Ensure that the AK Series CPU cooler is connected and the script has the correct Vendor ID and Product ID."
    )
except KeyboardInterrupt:
    print("Script terminated by user.")
finally:
    if "h" in locals():
        h.close()
