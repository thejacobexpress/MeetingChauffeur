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
  IndividualClass("Jacob Express", "thejacobexpress@gmail.com", "This person is the Chief Financial Officer of McKee Co."),
  IndividualClass("Jacob Work", "mckeejacob23@gmail.com", "This person is the Chief Marketing officer of McKee Co."),
  IndividualClass("Jacob Scholar", "jacobmckee192@gmail.com", ""),
];

class IndividualClass extends Recipient{

  String contact;
  List<GroupClass> groups = [];

  IndividualClass(super.name, this.contact, [super.info]);

}