// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayNoteAdapter extends TypeAdapter<DayNote> {
  @override
  final int typeId = 6;

  @override
  DayNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayNote(
      dateIso: fields[0] as String,
      content: fields[1] as String,
      updatedAt: fields[2] as DateTime,
      hasPendingSync: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DayNote obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dateIso)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.hasPendingSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
