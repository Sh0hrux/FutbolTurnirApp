import 'package:equatable/equatable.dart';
import '../../domain/entities/home_summary_entity.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeSuccess extends HomeState {
  final HomeSummaryEntity summary;
  final String? errorMessage;

  const HomeSuccess(this.summary, {this.errorMessage});

  @override
  List<Object?> get props => [summary, errorMessage];
}

class HomeFailure extends HomeState {
  final String message;

  const HomeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
