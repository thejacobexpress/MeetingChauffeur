import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';

/// Contains all of the ```GroupClass``` instances that exist.
List<GroupClass> groups = [
  GroupClass("Finance", [
    individuals[0]
  ], "This group is responsible for managing the financial operations of the company. This group has been having issues with the budget recently."),
  GroupClass("Marketing", [
    individuals[1]
  ], "This group is responsible for promoting the company's products and services. This group has been excelling in recent campaigns."),
  GroupClass("Executive", [
    
  ], "This group is responsible for the overall management of the company. This group has been working on a new strategic plan."),
  GroupClass("People", []),
];

/// Used to store an ```IndividualClass``` temporarily to use in a callback function to correctly update the state of the ```IndividualsPage.dart```, ```NewGroupPage.dart```, and ```SingleGroupPage.dart```.
/// 
/// Currently, this is used in the ```IndividualsPage.dart``` to add an instance of the ```IndividualClass``` to the ```Individuals``` list, updating the state of ```IndividualsPage.dart``` to show the new individual; ```NewGroupPage.dart``` to add an instance of the ```IndividualClass``` to the ```individuals``` list within the new group, updating the state of ```NewGroupPage.dart``` to show the new individual; ```SingleGroupPage.dart``` to add an instance of the ```IndividualClass``` to the ```individuals``` list in the group, updating the state of ```SingleGroupPage.dart``` to show the new individual.
IndividualClass indivToAdd = noIndividual;

/// Used to store a ```GroupClass``` temporarily to use in a callback function to correctly update the state of the ```GroupsPage```.
/// 
/// Currently, this is used in the ```NewGroupPage.dart``` to add an instance of the ```GroupClass``` to the ```Groups``` list, updating the state of ```GroupsPage.dart``` to show the new group.
GroupClass groupToAdd = noGroup; // Used to store a GroupClass temporarily to use in a callback function.

/// Used to represent a non-existent or default individual.
IndividualClass noIndividual = IndividualClass("None", "");
/// Used to represent a non-existent or default group.
GroupClass noGroup = GroupClass("None", []);

/// A group of ```IndividualClass``` instances.
class GroupClass extends Recipient{

  List<IndividualClass> individuals = [];

  GroupClass(super.name, this.individuals, [super.info]);

}