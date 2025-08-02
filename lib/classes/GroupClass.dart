import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';

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

IndividualClass indivToAdd = noIndividual; // Used to store an IndividualClass temporarily to use in a callback function.
GroupClass groupToAdd = noGroup; // Used to store a GroupClass temporarily to use in a callback function.

IndividualClass noIndividual = IndividualClass("None", "");
GroupClass noGroup = GroupClass("None", []);

class GroupClass extends Recipient{

  List<IndividualClass> individuals = [];

  GroupClass(super.name, this.individuals, [super.info]);

}