// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassSessionAdapter extends TypeAdapter<ClassSession> {
  @override
  final int typeId = 2;

  @override
  ClassSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSession(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      semesterId: fields[9] == null ? '' : fields[9] as String,
      date: fields[2] as DateTime,
      status: fields[3] as AttendanceStatus,
      isExtraClass: fields[4] as bool,
      notes: fields[5] as String?,
      durationMinutes: fields[6] as int,
      lastUpdated: fields[7] as DateTime?,
      hasPendingSync: fields[8] == null ? false : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ClassSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.isExtraClass)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.durationMinutes)
      ..writeByte(7)
      ..write(obj.lastUpdated)
      ..writeByte(8)
      ..write(obj.hasPendingSync)
      ..writeByte(9)
      ..write(obj.semesterId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 3;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.present;
      case 1:
        return AttendanceStatus.absent;
      case 2:
        return AttendanceStatus.cancelled;
      case 3:
        return AttendanceStatus.scheduled;
      default:
        return AttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(1);
        break;
      case AttendanceStatus.cancelled:
        writer.writeByte(2);
        break;
      case AttendanceStatus.scheduled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
