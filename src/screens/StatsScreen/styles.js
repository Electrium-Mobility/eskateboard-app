import { StyleSheet } from 'react-native';

export default StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      padding: 20,
    },
    dashboardItem: {
      margin: 10,
      backgroundColor: '#333333'
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