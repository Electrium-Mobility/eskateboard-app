import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';

// Mock Data - replace this with real data from your Bluetooth connection
const mockData = {
  speed: '25 km/h',
  battery: '85%',
  rangeLeftover: '15 km',
  rpm: '3200',
};

const SkateboardDashboard = () => {
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
      setDashboardData(data);
    };

    fetchData();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.dashboardItem}>
        <Text style={styles.label}>Speed</Text>
        <Text style={styles.value}>{dashboardData.speed}</Text>
      </View>
      <View style={styles.dashboardItem}>
        <Text style={styles.label}>Battery</Text>
        <Text style={styles.value}>{dashboardData.battery}</Text>
      </View>
      <View style={styles.dashboardItem}>
        <Text style={styles.label}>Range Leftover</Text>
        <Text style={styles.value}>{dashboardData.rangeLeftover}</Text>
      </View>
      <View style={styles.dashboardItem}>
        <Text style={styles.label}>RPM</Text>
        <Text style={styles.value}>{dashboardData.rpm}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  dashboardItem: {
    margin: 10,
  },
  label: {
    fontSize: 16,
    color: '#333',
  },
  value: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#000',
    },
});

export default SkateboardDashboard;