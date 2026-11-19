# The Mobile Ads SDK brings WorkManager 2.7.0, built on Room 2.2.5. Room
# creates WorkDatabase_Impl by reflection through its no-argument constructor,
# and Room 2.2.5's own rule keeps the class but not that constructor. R8 full
# mode (the default since AGP 8) then removes it, so a release build crashed
# at launch: androidx.startup -> WorkManager -> "Failed to create an instance
# of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
