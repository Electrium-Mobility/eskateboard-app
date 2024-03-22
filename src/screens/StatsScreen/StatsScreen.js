import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import styles from './styles';
import { TouchableOpacity } from 'react-native-gesture-handler';

export default function StatsScreen({navigation}) {
    // Mock Data - replace this with real data from your Bluetooth connection
    const mockData = {
        speed: 25,
        battery: 85,
        rangeLeftover: 15,
        rpm: 3200,
    };

    const [dashboardData, setDashboardData] = useState({
        speed: '',
        battery: '',
        rangeLeftover: '',
        rpm: '',
    });

    useEffect(() => {
        // Simulate fetching data from the skateboard
        // In a real app, replace this with your Bluetooth data fetching logic
        const fetchData = async () => {
            // Assuming you have a method to fetch data from the skateboard
            // const data = await fetchSkateboardDataViaBluetooth();
            const data = mockData; // using mock data for demonstration

            db.transaction((tx) => {
                tx.executeSql(
                    "INSERT INTO Stats (Battery, Range, RPM, Speed) VALUES (?,?,?,?)",
                    [data.battery, data.rangeLeftover, data.rpm, data.speed]
                );
            })

            data.speed = data.speed.toString() + " km/h"
            data.battery = data.battery.toString() + " %"
            data.rangeLeftover = data.rangeLeftover.toString() + " km"
            data.rpm = data.rpm.toString()
            setDashboardData(data);
        };
    
        fetchData();
    }, []);

    const onSpeedPress = () => {
        navigation.navigate('Speed')
    }

    const onBatteryPress = () => {
        navigation.navigate('Battery')
    }

    const onRangePress = () => {
        navigation.navigate('Range')
    }

    const onRPMPress = () => {
        navigation.navigate('RPM')
    }

    return (
        <View style={styles.container}>
            <TouchableOpacity style={styles.dashboardItem} onPress={() => onSpeedPress()}>
            <Text style={styles.label}>Speed</Text>
            <Text style={styles.value}>{dashboardData.speed}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.dashboardItem} onPress={() => onBatteryPress()}>
            <Text style={styles.label}>Battery</Text>
            <Text style={styles.value}>{dashboardData.battery}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.dashboardItem} onPress={() => onRangePress()}>
            <Text style={styles.label}>Range Leftover</Text>
            <Text style={styles.value}>{dashboardData.rangeLeftover}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.dashboardItem} onPress={() => onRPMPress()}>
            <Text style={styles.label}>RPM</Text>
            <Text style={styles.value}>{dashboardData.rpm}</Text>
            </TouchableOpacity>
        </View>
    );
};