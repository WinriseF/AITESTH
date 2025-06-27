import { QuestionModel } from "../model/QuestionModel"
import { getNormal, postNormal } from "../utls/HttpClient"
class GenerateQuestionDto {
  question?:string
  questionNum?:number
  questionFormat?:string
}
export const asyncGenerateQuestion =  (generateQuestionDto:GenerateQuestionDto)=>postNormal<string>("/question/asyncGenerateQuestion",generateQuestionDto)
export const selectQuestionByGenerateId =  (generateId:string)=>getNormal<QuestionModel[]>("/question/question/" + generateId )