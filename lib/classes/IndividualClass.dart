import 'package:http/http.dart';
import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';
import 'package:meeting_summarizer_app/widgets/Group.dart';

List<GroupClass> getGroups(IndividualClass indiv) {
  List<GroupClass> list = [];
  for(final group in groups) {
    for(final individual in group.individuals) {
      if(individual == indiv) {
        list.add(group);
        break;
      }
    }
  }
  return list;
}

List<IndividualClass> individuals = [
  IndividualClass("Jacob Express", "thejacobexpress@gmail.com", "This person is heavily involved with the financial but also the software side of the company."),
  IndividualClass("Jacob Main", "jacobmckee06@gmail.com")
];

class IndividualClass extends Recipient{

  String contact;
  List<GroupClass> groups = [];

  IndividualClass(super.name, this.contact, [super.info]);

}