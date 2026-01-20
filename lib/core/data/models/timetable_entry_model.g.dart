// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override
  final int typeId = 1;

  @override
  TimetableEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableEntry(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      semesterId: fields[8] == null ? '' : fields[8] as String,
      dayOfWeek: fields[2] as int,
      startTime: fields[3] as String,
      durationMinutes: fields[4] as int,
      isRecurring: fields[5] == null ? true : fields[5] as bool,
      lastUpdated: fields[6] as DateTime?,
      hasPendingSync: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.isRecurring)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.hasPendingSync)
      ..writeByte(8)
      ..write(obj.semesterId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
