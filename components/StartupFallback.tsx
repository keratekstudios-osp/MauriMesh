import React from "react";
import { View, ActivityIndicator } from "react-native";
export function StartupFallback(){return <View style={{flex:1,alignItems:"center",justifyContent:"center"}}><ActivityIndicator /></View>;}
export default StartupFallback;
