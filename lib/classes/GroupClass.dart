import 'package:meeting_summarizer_app/classes/IndividualClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';

List<GroupClass> groups = [
  GroupClass("Finance", [
    individuals[0]
  ]),
  GroupClass("Marketing", [
    individuals[1]
  ]),
  GroupClass("Executive", []),
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